import 'package:mesh_note/mindeditor/controller/controller.dart';
import 'package:mesh_note/mindeditor/view/toolbar/base/appearance_setting.dart';
import 'package:mesh_note/mindeditor/view/toolbar/icon_and_text_button.dart';
import 'package:flutter/material.dart';
import 'package:my_log/my_log.dart';
import 'base/movable_button.dart';

class PopupToolbar extends StatelessWidget {
  final Controller controller;
  final double toolBarHeight;
  final double maxWidth;
  final List<Widget> children;
  final AppearanceSetting appearance;

  const PopupToolbar({
    Key? key,
    required this.controller,
    this.toolBarHeight = 36,
    required this.children,
    required this.appearance,
    required this.maxWidth,
  }): super(key: key);

  factory PopupToolbar.basic({
    Key? key,
    required Controller controller,
    required BuildContext context,
    required double maxWidth,
  }) {
    AppearanceSetting defaultAppearance = _buildDefaultAppearance(context);
    var buttons = <Widget>[
      IconAndTextButton(
        appearance: defaultAppearance,
        controller: controller,
        text: 'All',
        tip: 'Select all content',
        onPressed: () {
          MyLogger.info('Select');
        },
      ),
      IconAndTextButton(
        appearance: defaultAppearance,
        controller: controller,
        text: 'Copy',
        tip: 'Copy content',
        onPressed: () {
          MyLogger.info('Copy');
        },
      ),
      IconAndTextButton(
        appearance: defaultAppearance,
        controller: controller,
        text: 'Cut',
        tip: 'Cut content',
        onPressed: () {
          MyLogger.info('Cut');
        },
      ),
      IconAndTextButton(
        appearance: defaultAppearance,
        controller: controller,
        text: 'Paste',
        tip: 'Paste content',
        onPressed: () {
          MyLogger.info('Paste');
        },
      ),
    ];
    final children = _addDivider(buttons);
    return PopupToolbar(
      key: key,
      controller: controller,
      children: children,
      appearance: defaultAppearance,
      maxWidth: maxWidth,
    );
  }

  static List<Widget> _addDivider(List<Widget> buttons) {
    final result = <Widget>[];
    bool first = true;
    for(final button in buttons) {
      if(first) {
        first = false;
      } else {
        result.add(VerticalDivider(
          indent: 8.0,
          endIndent: 8.0,
          width: 1.0,
          thickness: 1.0,
          color: Colors.grey[350],
        ));
      }
      result.add(button);
    }
    return result;
  }

  static AppearanceSetting _buildDefaultAppearance(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(16, 4, 16, 4);
    if(Controller().environment.isMobile()) {
      return AppearanceSetting(
        iconSize: 28,
        size: 32,
        fillColor: Theme.of(context).canvasColor,
        hoverColor: Theme.of(context).colorScheme.background,
        padding: padding,
      );
    }
    return AppearanceSetting(
      iconSize: 18,
      size: 36,
      fillColor: Theme.of(context).canvasColor,
      hoverColor: Theme.of(context).colorScheme.background,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget toolbar = Row(
      children: children,
    );
    if(controller.isDebugMode) {
      toolbar = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.green,
            width: 2,
          ),
        ),
        child: toolbar,
      );
    }
    Widget scroll = _buildScrollable(toolbar);
    final container = Container(
      height: toolBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: scroll,
    );
    return container;
  }

  Widget _buildScrollable(Widget toolbar) {
    // Mobile could use SingleChildScrollView to drag and scroll, but desktop not. So add left and right buttons in desktop environment
    if(controller.environment.isDesktop()) {
      return MovableToolbar(child: toolbar, height: toolBarHeight, appearance: appearance,);
    } else {
      Widget scroll = SingleChildScrollView(
        child: toolbar,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(1.0),
      );
      return scroll;
    }
  }
}
