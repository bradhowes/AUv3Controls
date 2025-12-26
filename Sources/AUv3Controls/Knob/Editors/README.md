# Editors

Some experiments on how to show a value editor for a knob. The original -- [EditorFeature](EditorFeature.swift) -- shows
a small entry in place of the knob with some fun animations going between the two. However, it does not work very well
when the keyboard appears on an real device. The [ValueEditorHost](ValueEditorHost.swift) modifier works much better
on real devices.

* CustomValueEditorHost -- experiment using [CustomAlert](https://github.com/divadretlaw/CustomAlert.git) package. There are some
unresolved issues when using in an AUv3 view.
* EditorFeature -- as mentioned above, this is the original editor which showed the text field in-line with the control. However,
it does not provide a vertical shift to keep out of the way of a virtual keyboard.
* NativeValueEditor -- simple editor that uses an alert with a text field to allow editing of the value.
* ValueEditorHost -- non-native version of the editor.
