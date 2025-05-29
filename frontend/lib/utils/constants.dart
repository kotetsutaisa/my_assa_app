const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',

  // ----------- windows ----------
  // 家
  // defaultValue: 'http://100.64.1.60:8000/api/',

  // 加工場
  // defaultValue: 'http://192.168.1.6:8000/api/',


  // ---------- mac ----------
  // defaultValue: 'http://127.0.0.1:8000/api/', // ← iOSエミュ用

  // 携帯
  // defaultValue: 'http://192.0.0.2:8000/api/',

  // 家
  // defaultValue: 'http://100.64.1.16:8000/api/',

  // 宗像
  // defaultValue: 'http://192.168.2.159:8000/api/',

  // 加工場
  defaultValue: 'http://192.168.1.4:8000/api/'
);


const String wsApiBaseUrl = String.fromEnvironment(
  'WS_API_BASE_URL',

  // 家
  // defaultValue: 'ws://100.64.1.16:8000',

  // 宗像
  // defaultValue: 'ws://192.168.2.159:8000',

  // 携帯
  // defaultValue: 'ws://192.0.0.2:8000',

  // defaultValue: 'ws://127.0.0.1:8000'

  // 加工場
  defaultValue: 'ws://192.168.1.4:8000'
);

