/// All wash program definitions, temperatures, spin speeds, process states, and error codes
/// ported from the original Data.java.
library;

class WashProgram {
  final int id;
  final String name;
  final List<int> temperatures;
  final List<int> spinSpeeds;
  final bool canPreWash;
  final bool canRinseHold;
  final bool canSoak;
  final bool canExtraRinse;
  final bool canTimeSaver;
  final int defaultTemp;
  final int defaultSpin;
  final int programCategory;

  const WashProgram({
    required this.id,
    required this.name,
    required this.temperatures,
    required this.spinSpeeds,
    this.canPreWash = false,
    this.canRinseHold = false,
    this.canSoak = false,
    this.canExtraRinse = false,
    this.canTimeSaver = false,
    this.defaultTemp = 0,
    this.defaultSpin = 0,
    this.programCategory = 1,
  });
}

class WashingData {
  // ─── Program IDs ───
  static const int cotton = 0;
  static const int cottonEco = 1;
  static const int synthetics = 2;
  static const int delicates = 3;
  static const int mixedLight = 4;
  static const int mixedHeavy = 5;
  static const int woollens = 6;
  static const int express = 7;
  static const int tubClean = 8;
  static const int additives = 9;
  static const int spinDry = 10;
  static const int beddings = 11;
  static const int babyWear = 12;
  static const int antiAllergen = 13;
  static const int cradleWash = 14;

  // ─── Temperature tables ───
  static const List<int> tempsCotton = [0, 30, 40, 55, 60, 75, 90];
  static const List<int> tempsCottonEco = [0, 30, 40, 55, 60];
  static const List<int> tempsSynthetics = [0, 30, 40, 55, 60];
  static const List<int> tempsDelicates = [0, 30, 40];
  static const List<int> tempsMixedLight = [0, 30, 40, 55, 60];
  static const List<int> tempsMixedHeavy = [0, 30, 40, 55, 60];
  static const List<int> tempsWoollens = [0, 30, 40];
  static const List<int> tempsExpress = [0, 30, 40];
  static const List<int> tempsTubClean = [60, 90];
  static const List<int> tempsAdditives = [0, 30, 40, 55, 60, 75, 90];
  static const List<int> tempsBeddings = [0, 30, 40, 55, 60, 75, 90];
  static const List<int> tempsBabyWear = [0, 30, 40, 55, 60, 75, 90];
  static const List<int> tempsAntiAllergen = [60, 75, 90];
  static const List<int> tempsCradleWash = [0, 30, 40];

  // ─── Spin speed tables ───
  static const List<int> spinsCotton = [0, 400, 600, 800, 1000, 1200, 1400];
  static const List<int> spinsCottonEco = [0, 400, 600, 800, 1000, 1200];
  static const List<int> spinsSynthetics = [0, 400, 600, 800, 1000];
  static const List<int> spinsDelicates = [0, 400, 600, 800];
  static const List<int> spinsMixedLight = [0, 400, 600, 800, 1000];
  static const List<int> spinsMixedHeavy = [0, 400, 600, 800, 1000, 1200, 1400];
  static const List<int> spinsWoollens = [0, 400, 600, 800];
  static const List<int> spinsExpress = [0, 400, 600, 800, 1000, 1200, 1400];
  static const List<int> spinsTubClean = [800];
  static const List<int> spinsAdditives = [0, 400, 600, 800, 1000, 1200, 1400];
  static const List<int> spinsSpinDry = [0, 400, 600, 800, 1000, 1200, 1400];
  static const List<int> spinsBeddings = [0, 400, 600, 800, 1000];
  static const List<int> spinsBabyWear = [0, 400, 600, 800, 1000, 1200, 1400];
  static const List<int> spinsAntiAllergen = [
    0,
    400,
    600,
    800,
    1000,
    1200,
    1400,
  ];
  static const List<int> spinsCradleWash = [0, 400, 600, 800];

  // ─── All programs ───
  static const List<WashProgram> programs = [
    WashProgram(
      id: cotton,
      name: 'Cotton',
      temperatures: tempsCotton,
      spinSpeeds: spinsCotton,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 40,
      defaultSpin: 1400,
      programCategory: 1,
    ),
    WashProgram(
      id: cottonEco,
      name: 'Cotton Eco',
      temperatures: tempsCottonEco,
      spinSpeeds: spinsCottonEco,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: false,
      defaultTemp: 40,
      defaultSpin: 1200,
      programCategory: 1,
    ),
    WashProgram(
      id: synthetics,
      name: 'Synthetics',
      temperatures: tempsSynthetics,
      spinSpeeds: spinsSynthetics,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 40,
      defaultSpin: 1000,
      programCategory: 2,
    ),
    WashProgram(
      id: delicates,
      name: 'Delicates',
      temperatures: tempsDelicates,
      spinSpeeds: spinsDelicates,
      canPreWash: false,
      canRinseHold: true,
      canSoak: false,
      canExtraRinse: true,
      canTimeSaver: false,
      defaultTemp: 30,
      defaultSpin: 800,
      programCategory: 2,
    ),
    WashProgram(
      id: mixedLight,
      name: 'Mixed Light',
      temperatures: tempsMixedLight,
      spinSpeeds: spinsMixedLight,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 30,
      defaultSpin: 1000,
      programCategory: 2,
    ),
    WashProgram(
      id: mixedHeavy,
      name: 'Mixed Heavy',
      temperatures: tempsMixedHeavy,
      spinSpeeds: spinsMixedHeavy,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 40,
      defaultSpin: 1400,
      programCategory: 1,
    ),
    WashProgram(
      id: woollens,
      name: 'Woollens',
      temperatures: tempsWoollens,
      spinSpeeds: spinsWoollens,
      canPreWash: false,
      canRinseHold: false,
      canSoak: false,
      canExtraRinse: false,
      canTimeSaver: false,
      defaultTemp: 30,
      defaultSpin: 800,
      programCategory: 2,
    ),
    WashProgram(
      id: express,
      name: 'Express',
      temperatures: tempsExpress,
      spinSpeeds: spinsExpress,
      canPreWash: false,
      canRinseHold: true,
      canSoak: false,
      canExtraRinse: true,
      canTimeSaver: false,
      defaultTemp: 30,
      defaultSpin: 1400,
      programCategory: 2,
    ),
    WashProgram(
      id: tubClean,
      name: 'Tub Clean',
      temperatures: tempsTubClean,
      spinSpeeds: spinsTubClean,
      canPreWash: false,
      canRinseHold: false,
      canSoak: false,
      canExtraRinse: false,
      canTimeSaver: false,
      defaultTemp: 90,
      defaultSpin: 800,
      programCategory: 1,
    ),
    WashProgram(
      id: additives,
      name: 'Additives',
      temperatures: tempsAdditives,
      spinSpeeds: spinsAdditives,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 40,
      defaultSpin: 1400,
      programCategory: 1,
    ),
    WashProgram(
      id: spinDry,
      name: 'Spin Dry',
      temperatures: <int>[],
      spinSpeeds: spinsSpinDry,
      canPreWash: false,
      canRinseHold: false,
      canSoak: false,
      canExtraRinse: false,
      canTimeSaver: false,
      defaultTemp: 0,
      defaultSpin: 1400,
      programCategory: 1,
    ),
    WashProgram(
      id: beddings,
      name: 'Beddings',
      temperatures: tempsBeddings,
      spinSpeeds: spinsBeddings,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 40,
      defaultSpin: 1000,
      programCategory: 1,
    ),
    WashProgram(
      id: babyWear,
      name: 'Baby Wear',
      temperatures: tempsBabyWear,
      spinSpeeds: spinsBabyWear,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: true,
      defaultTemp: 55,
      defaultSpin: 1400,
      programCategory: 1,
    ),
    WashProgram(
      id: antiAllergen,
      name: 'Anti Allergen',
      temperatures: tempsAntiAllergen,
      spinSpeeds: spinsAntiAllergen,
      canPreWash: true,
      canRinseHold: true,
      canSoak: true,
      canExtraRinse: true,
      canTimeSaver: false,
      defaultTemp: 60,
      defaultSpin: 1400,
      programCategory: 1,
    ),
    WashProgram(
      id: cradleWash,
      name: 'Cradle Wash',
      temperatures: tempsCradleWash,
      spinSpeeds: spinsCradleWash,
      canPreWash: false,
      canRinseHold: true,
      canSoak: false,
      canExtraRinse: true,
      canTimeSaver: false,
      defaultTemp: 30,
      defaultSpin: 800,
      programCategory: 2,
    ),
  ];

  // ─── Process state names (index = state ID from telemetry) ───
  static const List<String> processStates = [
    'Nothing', // 0
    'Pre-Wash', // 1
    'Soak', // 2
    'Main Wash', // 3
    'Rinse 1', // 4
    'Rinse 2', // 5
    'Rinse 3', // 6
    'Spin', // 7
    'Completed', // 8
    'Pause', // 9
    'Door Lock Fault', // 10
    'Delay Start', // 11
    'Cancelled', // 12
    'Dispenser', // 13
    'Pre-Wash + ChildLock', // 14
    'Soak + ChildLock', // 15
    'Main Wash + ChildLock', // 16
    'Rinse1 + ChildLock', // 17
    'Rinse2 + ChildLock', // 18
    'Rinse3 + ChildLock', // 19
    'Spin + ChildLock', // 20
    'Complete + ChildLock', // 21
    'Pause + ChildLock', // 22
    'Delay + ChildLock', // 23
    'RinseHold + ChildLock', // 24
  ];

  // ─── Error code names ───
  static const List<String> errorCodes = [
    'No error', // 0
    'Water overflow', // 1
    'Temperature sensor fault', // 2
    'Door open error', // 3
    'Water not drained', // 4
    'Door lock error', // 5
    'Unbalanced load', // 6
    'Water not filling', // 7
    'Motor RPM not sensed', // 8
    'Communication error', // 9
    'Heater error', // 10
    'Motor fault', // 11
    'Pump/Drain motor error', // 12
    'Program interrupted', // 13
    'Dry error', // 14
    'High unbalanced load', // 15
  ];

  static String getProcessName(int stateId) {
    if (stateId >= 0 && stateId < processStates.length) {
      return processStates[stateId];
    }
    return 'Unknown ($stateId)';
  }

  static String getErrorName(int errorId) {
    if (errorId >= 0 && errorId < errorCodes.length) {
      return errorCodes[errorId];
    }
    return 'Unknown error ($errorId)';
  }

  static WashProgram? getProgramById(int id) {
    if (id >= 0 && id < programs.length) return programs[id];
    return null;
  }
}
