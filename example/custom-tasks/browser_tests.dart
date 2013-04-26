import 'dart:html';
import 'dart:async';

import 'package:js/js.dart' as js;
import 'package:js/js_wrapping.dart' as jsw;
import 'package:google_drive_realtime/google_drive_realtime.dart' as rt;
import 'package:google_drive_realtime/google_drive_realtime_custom.dart' as rtc;

class Task extends rt.CollaborativeObject {
  static const NAME = 'Task';
  static void registerType() {
    js.context.Task = new js.Callback.many((){});
    rtc.registerType(js.context.Task, NAME);
    js.context.Task.prototype.title = rtc.collaborativeField('title');
    js.context.Task.prototype.date = rtc.collaborativeField('date');
  }
  static Task cast(js.Proxy proxy) => proxy == null ? null : new Task.fromProxy(proxy);

  Task(rt.Model model) : this.fromProxy(model.create(NAME).$unsafe);
  Task.fromProxy(js.Proxy proxy) : super.fromProxy(proxy);

  String get title => $unsafe.title;
  DateTime get date => jsw.JsDateToDateTimeAdapter.cast($unsafe.date);
  set title(String title) => $unsafe.title = title;
  set date(DateTime date) => $unsafe.date = new jsw.JsDateToDateTimeAdapter(date);
}

initializeModel(js.Proxy modelProxy) {
  var model = rt.Model.cast(modelProxy);
  var tasks = model.createList();
  model.root.set('tasks', tasks);
}

/**
 * This function is called when the Realtime file has been loaded. It should
 * be used to initialize any user interface components and event handlers
 * depending on the Realtime model. In this case, create a text control binder
 * and bind it to our string model that we created in initializeModel.
 * @param doc {gapi.drive.realtime.Document} the Realtime document.
 */
onFileLoaded(docProxy) {
  var doc = rt.Document.cast(js.retain(docProxy));
  var tasks = rt.CollaborativeList.cast(doc.model.root.get('tasks'));
  js.retain(tasks);

  // collaborators listener
  doc.onCollaboratorJoined.listen((rt.CollaboratorJoinedEvent e){
    print("user joined : ${e.collaborator.displayName}");
  });
  doc.onCollaboratorLeft.listen((rt.CollaboratorLeftEvent e){
    print("user left : ${e.collaborator.displayName}");
  });

  final ulTasks = document.getElementById('tasks') as UListElement;
  final task = document.getElementById('task') as TextInputElement;
  final add = document.getElementById('add') as ButtonElement;

  final updateTasksList = (){
    ulTasks.children.clear();
    for(int i = 0; i < tasks.length; i++) {
      ulTasks.children.add(new LIElement()..text = tasks.get(i).title);
    }
  };

  document.getElementById('add').onClick.listen((_){
    tasks.push(new Task(doc.model)..title = task.value);
    task.value = "";
    task.focus();
  });

  // update input on changes
  tasks.onObjectChanged.listen((rt.ObjectChangedEvent e){
    updateTasksList();
  });

  // Enabling UI Elements.
  task.disabled = false;
  add.disabled = false;

  // init list
  updateTasksList();
}

/**
 * Options for the Realtime loader.
 */
get realtimeOptions => js.map({
   /**
  * Client ID from the APIs Console.
  */
  'clientId': 'INSERT YOUR CLIENT ID HERE',

   /**
  * The ID of the button to click to authorize. Must be a DOM element ID.
  */
   'authButtonElementId': 'authorizeButton',

   /**
  * Function to be called when a Realtime model is first created.
  */
   'initializeModel': new js.Callback.once(initializeModel),

   /**
  * Autocreate files right after auth automatically.
  */
   'autoCreate': true,

   /**
  * Autocreate files right after auth automatically.
  */
   'defaultTitle': "New Realtime Quickstart File",

   /**
  * Function to be called every time a Realtime file is loaded.
  */
   'onFileLoaded': new js.Callback.many(onFileLoaded)
});


main() {
  var realtimeLoader = new js.Proxy(js.context.rtclient.RealtimeLoader, realtimeOptions);
  realtimeLoader.start(new js.Callback.once((){
    Task.registerType();
  }));
}
