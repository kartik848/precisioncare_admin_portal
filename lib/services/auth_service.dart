import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  bool _isFirebaseAvailable = false;

  AuthService() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isFirebaseAvailable = true;
    } catch (e) {
      debugPrint('AuthService Firebase init note: $e');
      _isFirebaseAvailable = false;
    }
  }

  // Get current user profile (Instant local cache first so user stays logged in across sessions)
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user_profile');

      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        final profile = UserProfile.fromMap(data, data['uid'] ?? 'user_active');

        // Refresh in background without blocking instant app startup
        if (_isFirebaseAvailable && _firestore != null && profile.email.isNotEmpty) {
          _syncFreshProfileInBackground(profile);
        }
        return profile;
      }

      // If no local cache, check Firebase Auth session
      if (_isFirebaseAvailable && _auth?.currentUser != null) {
        final uid = _auth!.currentUser!.uid;
        final email = _auth!.currentUser!.email?.toLowerCase();
        if (_firestore != null) {
          try {
            final doc = await _firestore!.collection('users').doc(uid).get().timeout(const Duration(seconds: 3));
            if (doc.exists && doc.data() != null) {
              final profile = UserProfile.fromMap(doc.data()!, uid);
              await _cacheUserLocally(profile);
              return profile;
            }
            if (email != null && email.isNotEmpty) {
              final snap = await _firestore!.collection('users').where('email', isEqualTo: email).limit(1).get().timeout(const Duration(seconds: 3));
              if (snap.docs.isNotEmpty) {
                final profile = UserProfile.fromMap(snap.docs.first.data(), snap.docs.first.id);
                await _cacheUserLocally(profile);
                return profile;
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('getCurrentUserProfile note: $e');
    }
    return null;
  }

  void _syncFreshProfileInBackground(UserProfile cached) async {
    try {
      if (_firestore == null) return;
      final snap = await _firestore!.collection('users').where('email', isEqualTo: cached.email.toLowerCase()).limit(1).get();
      if (snap.docs.isNotEmpty) {
        final fresh = UserProfile.fromMap(snap.docs.first.data(), snap.docs.first.id);
        await _cacheUserLocally(fresh);
      }
    } catch (_) {}
  }

  // Sign in with Firebase Auth & Firestore
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Admin Credentials Check (For Web Admin)
    if (cleanEmail == 'admin@gmail.com' && cleanPassword == '1234') {
      final adminProfile = UserProfile(
        uid: 'admin_precisioncare_001',
        name: 'PrecisionCare Admin Officer',
        age: 35,
        sex: 'Male',
        address: 'PrecisionCare Diagnostic Centre, Health City',
        mobile: '+91 92709 88595',
        email: 'admin@gmail.com',
      );
      await _cacheUserLocally(adminProfile);
      return adminProfile;
    }

    // 2. Check local cached user first for existing profile photo and info
    UserProfile? cachedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user_profile');
      if (userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        if (data['email']?.toString().toLowerCase() == cleanEmail) {
          cachedUser = UserProfile.fromMap(data, data['uid'] ?? 'user_active');
        }
      }
    } catch (_) {}

    // 3. Try Firebase Auth
    if (_isFirebaseAvailable && _auth != null) {
      try {
        final credential = await _auth!.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );

        final uid = credential.user!.uid;

        // Check Firestore by UID
        if (_firestore != null) {
          final doc = await _firestore!.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
            final profile = UserProfile.fromMap(doc.data()!, uid);
            await _cacheUserLocally(profile);
            return profile;
          }

          // Check Firestore by Email query
          final emailQuery = await _firestore!
              .collection('users')
              .where('email', isEqualTo: cleanEmail)
              .limit(1)
              .get();

          if (emailQuery.docs.isNotEmpty) {
            final docData = emailQuery.docs.first.data();
            final profile = UserProfile.fromMap(docData, emailQuery.docs.first.id);
            // Link UID in Firestore
            await _firestore!.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
            await _cacheUserLocally(profile);
            return profile;
          }
        }

        // If cached user has photo and details, use it
        if (cachedUser != null) {
          final profile = cachedUser.copyWith(uid: uid);
          if (_firestore != null) {
            await _firestore!.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
          }
          await _cacheUserLocally(profile);
          return profile;
        }

        final profile = UserProfile(
          uid: uid,
          name: credential.user!.displayName ?? cleanEmail.split('@').first.toUpperCase(),
          age: 25,
          sex: 'Male',
          address: '',
          mobile: '',
          email: cleanEmail,
        );

        if (_firestore != null) {
          await _firestore!.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
        }

        await _cacheUserLocally(profile);
        return profile;
      } on FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuthException during signIn: ${e.code} - ${e.message}');

        // Fallback: Query Firestore users collection by email
        if (_firestore != null) {
          try {
            final snapshot = await _firestore!
                .collection('users')
                .where('email', isEqualTo: cleanEmail)
                .limit(1)
                .get();

            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              final profile = UserProfile.fromMap(doc.data(), doc.id);
              await _cacheUserLocally(profile);
              return profile;
            }
          } catch (_) {}
        }

        if (cachedUser != null) {
          return cachedUser;
        }

        String msg = 'Sign in failed';
        if (e.code == 'user-not-found') {
          msg = 'No registered patient found with this email. Please click "Create ID / Register".';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          msg = 'Incorrect password. Please verify and try again.';
        } else if (e.code == 'invalid-email') {
          msg = 'Please enter a valid email address.';
        } else if (e.code == 'user-disabled') {
          msg = 'This patient account has been restricted by Admin.';
        } else if (e.code == 'operation-not-allowed') {
          final uid = 'PID_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
          final profile = UserProfile(
            uid: uid,
            name: cleanEmail.split('@').first.toUpperCase(),
            age: 25,
            sex: 'Male',
            address: '',
            mobile: '',
            email: cleanEmail,
          );
          if (_firestore != null) {
            await _firestore!.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
          }
          await _cacheUserLocally(profile);
          return profile;
        } else if (e.message != null) {
          msg = e.message!;
        }
        throw Exception(msg);
      } catch (e) {
        debugPrint('General signIn error: $e');
        if (cachedUser != null) return cachedUser;

        final uid = 'PID_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        final profile = UserProfile(
          uid: uid,
          name: cleanEmail.split('@').first.toUpperCase(),
          age: 25,
          sex: 'Male',
          address: '',
          mobile: '',
          email: cleanEmail,
        );
        await _cacheUserLocally(profile);
        return profile;
      }
    }

    // 4. Offline / Local fallback
    if (_firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final profile = UserProfile.fromMap(doc.data(), doc.id);
          await _cacheUserLocally(profile);
          return profile;
        }
      } catch (_) {}
    }

    if (cachedUser != null) return cachedUser;

    final uid = 'PID_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final profile = UserProfile(
      uid: uid,
      name: cleanEmail.split('@').first.toUpperCase(),
      age: 25,
      sex: 'Male',
      address: '',
      mobile: '',
      email: cleanEmail,
    );
    await _cacheUserLocally(profile);
    return profile;
  }

  // Sign up new user with real Firebase Auth & Firestore profile
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String sex,
    DateTime? dob,
    required String address,
    required String mobile,
    String? profileImageUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    String uid = 'PID_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // 1. Try Firebase Auth createUser
    if (_isFirebaseAvailable && _auth != null) {
      try {
        final credential = await _auth!.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        uid = credential.user!.uid;
        await credential.user?.updateDisplayName(name.trim());
        if (profileImageUrl != null && profileImageUrl.isNotEmpty && profileImageUrl.startsWith('http')) {
          await credential.user?.updatePhotoURL(profileImageUrl);
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuthException during signUp: ${e.code} - ${e.message}');
        
        if (e.code == 'email-already-in-use') {
          try {
            final credential = await _auth!.signInWithEmailAndPassword(
              email: cleanEmail,
              password: cleanPassword,
            );
            uid = credential.user!.uid;
          } catch (_) {
            if (_firestore != null) {
              final snap = await _firestore!.collection('users').where('email', isEqualTo: cleanEmail).limit(1).get();
              if (snap.docs.isNotEmpty) {
                uid = snap.docs.first.id;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('General error during auth signUp: $e');
      }
    }

    final profile = UserProfile(
      uid: uid,
      name: name.trim(),
      age: age,
      sex: sex,
      dob: dob,
      address: address.trim(),
      mobile: mobile.trim(),
      email: cleanEmail,
      profileImageUrl: profileImageUrl,
      createdAt: DateTime.now(),
    );

    // 2. Save directly to Firestore users collection
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
        debugPrint('Successfully saved user profile to Firestore: $uid with photo: $profileImageUrl');
      } catch (e) {
        debugPrint('Firestore user save note: $e');
      }
    }

    // 3. Cache locally
    await _cacheUserLocally(profile);
    return profile;
  }

  // Real-time stream of all users for Admin Panel
  Stream<List<UserProfile>> streamAllUsers() {
    if (_isFirebaseAvailable && _firestore != null) {
      return _firestore!.collection('users').snapshots().handleError((e) {
        debugPrint('Users stream notice: $e');
      }).map((snapshot) {
        final list = snapshot.docs.map((doc) => UserProfile.fromMap(doc.data(), doc.id)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }
    return Stream.value([]);
  }

  // Real User Directory for Admin Panel
  Future<List<UserProfile>> getAllUsers() async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        final snapshot = await _firestore!.collection('users').get();
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((doc) => UserProfile.fromMap(doc.data(), doc.id)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        }
      } catch (e) {
        debugPrint('getAllUsers Firestore error: $e');
      }
    }

    final current = await getCurrentUserProfile();
    if (current != null && current.email != 'admin@gmail.com') {
      return [current];
    }
    return [];
  }

  // Update Profile
  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
    await _cacheUserLocally(profile);
    return profile;
  }

  // Block/Unblock User
  Future<void> toggleBlockUser(String uid, bool blockStatus) async {
    if (_isFirebaseAvailable && _firestore != null) {
      try {
        await _firestore!.collection('users').doc(uid).update({'isBlocked': blockStatus});
      } catch (_) {}
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (_isFirebaseAvailable && _auth != null) {
      try {
        await _auth!.signOut();
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('cached_user_profile');
    } catch (_) {}
  }

  Future<void> _cacheUserLocally(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('cached_user_profile', jsonEncode(user.toMap()..['uid'] = user.uid));
    } catch (_) {}
  }
}
