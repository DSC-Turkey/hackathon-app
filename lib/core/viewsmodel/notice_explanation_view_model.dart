import 'dart:convert';

import 'package:MufettisWidgetApp/apis/account/acoount_api.dart';
import 'package:MufettisWidgetApp/apis/city/city_api.dart';
import 'package:MufettisWidgetApp/apis/district/district_api.dart';
import 'package:MufettisWidgetApp/apis/notice/notice_api.dart';
import 'package:MufettisWidgetApp/core/enum/singing_character.dart';
import 'package:MufettisWidgetApp/core/enum/viewstate.dart';
import 'package:MufettisWidgetApp/model/city.dart';
import 'package:MufettisWidgetApp/model/district.dart';
import 'package:MufettisWidgetApp/model/notice.dart';
import 'package:MufettisWidgetApp/model/reponseModel/reponseNotice.dart';
import 'package:MufettisWidgetApp/model/user.dart';
import 'package:MufettisWidgetApp/screen/notice/success_share.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../shared_prefernces_api.dart';
import 'base_model.dart';

//Kullanıcının Bildirim eklemesini sayğalan model
class NoticeExplanationdViewModel extends BaseModel {
  final noticeExplanationScaffoldKey = GlobalKey<ScaffoldState>(debugLabel: "_noticeExplanationScaffoldKey");

  BuildContext _context;

  BuildContext get context => _context;

  NoticeExplanationdViewModel() {}

  void setContext(BuildContext context) {
    this._context = context;
  }

  Future<bool> saveNotice(Notice notice, SingingCharacter character, String imagePath) {
    notice.noticeStatus = 1;
    notice.noticeDate = DateTime.now().toString();
    notice.userId = SharedManager().loginRequest.id;
    notice.photoName = imagePath.split('/').last.split('.').first;
    if (character == SingingCharacter.cityNotice) {
      notice.reportedMunicipality = notice.city;
      notice.noticeStatus = 3;
      CityApiService.instance.getCity(notice.city).then((responseCity) {
        if (responseCity.statusCode == 200) {
          Map cityMap = jsonDecode(responseCity.body);
          notice.twetterAddress = "@" + City.fromJson(cityMap).twitterAddress;
          NoticeApiServices.instance.createNotice(notice).then((responseNotice) {
            if (responseNotice.statusCode == 201) {
              Map noticeMap = jsonDecode(responseNotice.body);
              notice.id = Notice.fromJson(noticeMap).id;
              NoticeApiServices.instance.createNoticePhoto(imagePath, notice.photoName).then((response) {
                if (response.statusCode == 200) {
                  var userLogin = SharedManager().loginRequest;

                  NoticeApiServices.instance.getmyNotice(userLogin.id).then((response) {
                    if (response.statusCode == 200) {
                      Map<String, dynamic> map = jsonDecode(response.body);
                      var responseNotice = ResponseNotice.fromJson(map);
                      userLogin.noticies = new List<Notice>();
                      userLogin.noticies = responseNotice.notices;
                      SharedManager().loginRequest = userLogin;
                    } else {
                      SharedManager().loginRequest = userLogin;
                    }
                  });
                  Navigator.of(context)
                      .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => SuccessShare(notice)), (Route<dynamic> route) => false);
                  // Navigator.push(context, MaterialPageRoute(builder: (_context) => SuccessShare(notice)));
                  return true;
                }
              });
            }
          });
        }
      });
    }
    if (character == SingingCharacter.districtNotice) {
      notice.reportedMunicipality = notice.district;
      notice.noticeStatus = 5;

      DistrictApiServices.instance.getDistrict(notice.city, notice.district).then((responseDistrict) {
        if (responseDistrict.statusCode == 200) {
          Map districtMap = jsonDecode(responseDistrict.body);
          notice.twetterAddress = "@" + District.fromJson(districtMap).twitterAddress;
          NoticeApiServices.instance.createNotice(notice).then((responseNotice) {
            Map noticeMap = jsonDecode(responseNotice.body);
            //setState(() {
            notice.id = Notice.fromJson(noticeMap).id;
            if (responseNotice.statusCode == 201) {
              NoticeApiServices.instance.createNoticePhoto(imagePath, notice.photoName).then((responseImage) {
                setState(ViewState.Busy);

                // setState(() async {
                if (responseImage.statusCode == 200) {
                  var userLogin = SharedManager().loginRequest;

                  NoticeApiServices.instance.getmyNotice(userLogin.id).then((response) {
                    if (response.statusCode == 200) {
                      setState(ViewState.Idle);
                      Map<String, dynamic> map = jsonDecode(response.body);
                      var responseNotice = ResponseNotice.fromJson(map);
                      userLogin.noticies = new List<Notice>();
                      userLogin.noticies = responseNotice.notices;
                      SharedManager().loginRequest = userLogin;
                    } else {
                      setState(ViewState.Idle);
                      SharedManager().loginRequest = userLogin;
                    }
                  });

                  Navigator.push(context, MaterialPageRoute(builder: (_context) => SuccessShare(notice)));
                  return true;
                }
                //  });
              });
            }
            //  });
          });
        }
      });
    }
  }
}
