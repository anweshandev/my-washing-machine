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
  // Must match the native Java bridge getProcessName() exactly.
  static const List<String> processStates = [
    'Nothing', // 0
    'Standby', // 1
    'Initializing', // 2
    'Pre-Wash', // 3
    'Main Wash', // 4
    'Extra Rinse', // 5
    'Extra Rinse', // 6
    'Extra Rinse', // 7
    'Rinse', // 8
    'Rinse', // 9
    'Rinse', // 10
    'Final Spin', // 11
    'Anticrease', // 12
    'End', // 13
    'Pause', // 14
    'Soak', // 15
    'Rinse Hold', // 16
    'Heating', // 17
    'Drain', // 18
    'Intermediate Spin', // 19
    'Delay Start', // 20
    'Door Locking', // 21
    'Door Unlocking', // 22
    'End (Child Lock)', // 23
    'Rinse Hold (Child Lock)', // 24
  ];

  // ─── Error code names ───
  // Must match the native Java bridge getErrorName() exactly.
  static const List<String> errorCodes = [
    'No error', // 0
    'Door locked', // 1
    'Water overflow', // 2
    'Pressostat', // 3
    'Motor', // 4
    'Motor triac', // 5
    'Over heating', // 6
    'Door open', // 7
    'No water', // 8
    'Low water pressure', // 9
    'Heater', // 10
    'NTC', // 11
    'Drain pump', // 12
    'Low voltage', // 13
    'High voltage', // 14
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
