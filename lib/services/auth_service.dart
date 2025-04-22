import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // for storing data in cloud firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // for authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // for sign up
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
    String? phone, // เพิ่มพารามิเตอร์เบอร์โทรศัพท์ (ไม่บังคับ)
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        // for register user in firebase auth with email and password
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // สร้าง map ข้อมูลผู้ใช้
        Map<String, dynamic> userData = {
          'name': name,
          'email': email,
          'uid': credential.user!.uid,
        };

        // เพิ่มข้อมูลเบอร์โทรศัพท์ถ้ามีการระบุ
        if (phone != null && phone.isNotEmpty) {
          userData['phone'] = phone;
        }

        // for adding user to our cloud firestore
        await _firestore
            .collection("users")
            .doc(credential.user!.uid)
            .set(userData);

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  // for login
  Future<String> loginUser({
    required String email,
    required String password,
    String? age, // เพิ่มพารามิเตอร์อายุสำหรับอัพเดตข้อมูล (ไม่บังคับ)
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // login user with email and password
        UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // อัพเดตข้อมูลอายุถ้ามีการระบุ

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  // for logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // เพิ่มเมธอดสำหรับอัพเดตข้อมูลผู้ใช้
  Future<String> updateUserData({
    required String uid,
    String? name,
    String? email,
    String? phone,
  }) async {
    String res = "Some error occurred";
    try {
      Map<String, dynamic> dataToUpdate = {};

      if (name != null && name.isNotEmpty) {
        dataToUpdate['name'] = name;
      }

      if (email != null && email.isNotEmpty) {
        dataToUpdate['email'] = email;
      }

      if (phone != null) {
        dataToUpdate['phone'] = phone;
      }

      if (dataToUpdate.isNotEmpty) {
        await _firestore.collection("users").doc(uid).update(dataToUpdate);

        res = "success";
      } else {
        res = "No data to update";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }
}
