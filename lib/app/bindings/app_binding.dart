import 'package:get/get.dart';
import '../controllers/prediction_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PredictionController>(() => PredictionController(), fenix: true);
  }
}
