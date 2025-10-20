import 'package:auto_size_text/auto_size_text.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../consts.dart';
import '../../desktop/widgets/tabbar_widget.dart';
import '../../models/chat_model.dart';
import '../../models/model.dart';
import 'chat_page.dart';

class DraggableChatWindow extends StatelessWidget {
  const DraggableChatWindow(
      {Key? key,
      this.position = Offset.zero,
      required this.width,
      required this.height,
      required this.chatModel})
      : super(key: key);

  final Offset position;
  final double width;
  final double height;
  final ChatModel chatModel;

  @override
  Widget build(BuildContext context) {
    if (draggablePositions.chatWindow.isInvalid()) {
      draggablePositions.chatWindow.update(position);
    }
    return isIOS
        ? IOSDraggable(
            position: draggablePositions.chatWindow,
            chatModel: chatModel,
            width: width,
            height: height,
            builder: (context) {
              return Column(
                children: [
                  _buildMobileAppBar(context),
                  Expanded(
                    child: ChatPage(chatModel: chatModel),
                  ),
                ],
              );
            },
          )
        : Draggable(
            checkKeyboard: true,
            position: draggablePositions.chatWindow,
            width: width,
            height: height,
            chatModel: chatModel,
            builder: (context, onPanUpdate) {
              final child = Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: CustomAppBar(
                  onPanUpdate: onPanUpdate,
                  appBar: (isDesktop || isWebDesktop)
                      ? _buildDesktopAppBar(context)
                      : _buildMobileAppBar(context),
                ),
                body: ChatPage(chatModel: chatModel),
              );
              return Container(
                  decoration:
                      BoxDecoration(border: Border.all(color: MyTheme.border)),
                  child: child);
            });
  }

  Widget _buildMobileAppBar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                translate("Chat"),
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'WorkSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    chatModel.hideChatWindowOverlay();
                  },
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  )),
              IconButton(
                  onPressed: () {
                    chatModel.hideChatWindowOverlay();
                    chatModel.hideChatIconOverlay();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Theme.of(context).hintColor.withOpacity(0.4)))),
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Obx(() => Opacity(
                  opacity: chatModel.isWindowFocus.value ? 1.0 : 0.4,
                  child: Row(children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 6),
                    Text(translate("Chat"))
                  ])))),
          Padding(
              padding: EdgeInsets.all(2),
              child: ActionIcon(
                message: 'Close',
                icon: IconFont.close,
                onTap: chatModel.hideChatWindowOverlay,
                isClose: true,
                boxSize: 32,
              ))
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GestureDragUpdateCallback onPanUpdate;
  final Widget appBar;

  const CustomAppBar(
      {Key? key, required this.onPanUpdate, required this.appBar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onPanUpdate: onPanUpdate, child: appBar);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// floating buttons of back/home/recent actions for android
class DraggableMobileActions extends StatelessWidget {
  final double scale;
  final DraggableKeyPosition position;
  final double width;
  final double height;
  final VoidCallback onBackPressed;
  final VoidCallback onHomePressed;
  final VoidCallback onRecentPressed;
  final VoidCallback? onHidePressed;
  final FFI? session; // 添加会话参数

  const DraggableMobileActions({
    Key? key,
    required this.scale,
    required this.position,
    required this.width,
    required this.height,
    required this.onBackPressed,
    required this.onHomePressed,
    required this.onRecentPressed,
    this.onHidePressed,
    this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;
    final buttonSize = 40.0 * scale;
    final iconSize = 20.0 * scale;
    final fontSize = 12.0 * scale;

    return Draggable(
      position: position,
      width: scaledWidth,
      height: scaledHeight,
      builder: (context, onPanUpdate) {
        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: scaledWidth,
                height: scaledHeight,
                decoration: BoxDecoration(
                  color: MyTheme.color(context).toolbarBg,
                  borderRadius: BorderRadius.circular(20 * scale),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 5 * scale,
                      top: (scaledHeight - buttonSize) / 2,
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: TextButton(
                          onPressed: onBackPressed,
                          style: flatButtonStyle,
                          child: Icon(
                            Icons.arrow_back_ios_new_outlined,
                            size: iconSize,
                            color: MyTheme.color(context).toolbarIcon,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (scaledWidth - 120 * scale) / 2,
                      top: (scaledHeight - buttonSize) / 2,
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: TextButton(
                          onPressed: onHomePressed,
                          style: flatButtonStyle,
                          child: Icon(
                            Icons.home_outlined,
                            size: iconSize,
                            color: MyTheme.color(context).toolbarIcon,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 90 * scale,
                      top: (scaledHeight - buttonSize) / 2,
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: TextButton(
                          onPressed: onRecentPressed,
                          style: flatButtonStyle,
                          child: Icon(
                            Icons.more_horiz,
                            size: iconSize,
                            color: MyTheme.color(context).toolbarIcon,
                          ),
                        ),
                      ),
                    ),
                    // 添加黑屏控制按钮
                    if (session != null && session!.ffiModel.isPeerAndroid)
                      Positioned(
                        right: 45 * scale,
                        top: (scaledHeight - buttonSize) / 2,
                        child: SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: Obx(() => TextButton(
                            onPressed: () {
                              // 发送黑屏控制命令
                              bind.sessionTogglePrivacyMode(
                                sessionId: session!.sessionId,
                                implKey: "privacy_mode_impl_virtual_display",
                                on: !session!.ffiModel.isPeerBlackScreen.value,
                              );
                              // 更新本地状态
                              session!.ffiModel.isPeerBlackScreen.value = !session!.ffiModel.isPeerBlackScreen.value;
                            },
                            style: flatButtonStyle,
                            child: Icon(
                              session!.ffiModel.isPeerBlackScreen.isTrue 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                              size: iconSize,
                              color: session!.ffiModel.isPeerBlackScreen.isTrue
                                ? MyTheme.accent
                                : MyTheme.color(context).toolbarIcon,
                            ),
                          )),
                        ),
                      ),
                    Positioned(
                      right: 5 * scale,
                      top: (scaledHeight - buttonSize) / 2,
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: TextButton(
                          onPressed: onHidePressed,
                          style: flatButtonStyle,
                          child: Icon(
                            Icons.close,
                            size: iconSize,
                            color: MyTheme.color(context).toolbarIcon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: PanGestureDetector(
                onPanUpdate: onPanUpdate,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class DraggableKeyPosition {
  final String key;
  Offset _pos;
  late Debouncer<int> _debouncerStore;
  DraggableKeyPosition(this.key)
      : _pos = DraggablePositions.kInvalidDraggablePosition;

  get pos => _pos;

  _loadPosition(String k) {
    final value = bind.getLocalFlutterOption(k: k);
    if (value.isNotEmpty) {
      final parts = value.split(',');
      if (parts.length == 2) {
        return Offset(double.parse(parts[0]), double.parse(parts[1]));
      }
    }
    return DraggablePositions.kInvalidDraggablePosition;
  }

  load() {
    _pos = _loadPosition(key);
    _debouncerStore = Debouncer<int>(const Duration(milliseconds: 500),
        onChanged: (v) => _store(), initialValue: 0);
  }

  update(Offset pos) {
    _pos = pos;
    _triggerStore();
  }

  // Adjust position to keep it in the screen
  // Only used for desktop and web desktop
  tryAdjust(double w, double h, double scale) {
    final size = MediaQuery.of(Get.context!).size;
    w = w * scale;
    h = h * scale;
    double x = _pos.dx;
    double y = _pos.dy;
    if (x + w > size.width) {
      x = size.width - w;
    }
    final tabBarHeight = isDesktop ? kDesktopRemoteTabBarHeight : 0;
    if (y + h > (size.height - tabBarHeight)) {
      y = size.height - tabBarHeight - h;
    }
    if (x < 0) {
      x = 0;
    }
    if (y < 0) {
      y = 0;
    }
    if (x != _pos.dx || y != _pos.dy) {
      update(Offset(x, y));
    }
  }

  isInvalid() {
    return _pos == DraggablePositions.kInvalidDraggablePosition;
  }

  _triggerStore() => _debouncerStore.value = _debouncerStore.value + 1;
  _store() {
    bind.setLocalFlutterOption(k: key, v: '${_pos.dx},${_pos.dy}');
  }
}

class DraggablePositions {
  static const kChatWindow = 'draggablePositionChat';
  static const kMobileActions = 'draggablePositionMobile';
  static const kIOSDraggable = 'draggablePositionIOS';

  static const kInvalidDraggablePosition = Offset(-999999, -999999);
  final chatWindow = DraggableKeyPosition(kChatWindow);
  final mobileActions = DraggableKeyPosition(kMobileActions);
  final iOSDraggable = DraggableKeyPosition(kIOSDraggable);

  load() {
    chatWindow.load();
    mobileActions.load();
    iOSDraggable.load();
  }
}

DraggablePositions draggablePositions = DraggablePositions();

class Draggable extends StatefulWidget {
  Draggable(
      {Key? key,
      this.checkKeyboard = false,
      this.checkScreenSize = false,
      required this.position,
      required this.width,
      required this.height,
      this.chatModel,
      required this.builder})
      : super(key: key);

  final bool checkKeyboard;
  final bool checkScreenSize;
  final DraggableKeyPosition position;
  final double width;
  final double height;
  final ChatModel? chatModel;
  final Widget Function(BuildContext, GestureDragUpdateCallback) builder;

  @override
  State<StatefulWidget> createState() => _DraggableState(chatModel);
}

class _DraggableState extends State<Draggable> {
  late ChatModel? _chatModel;
  bool _keyboardVisible = false;
  double _saveHeight = 0;
  double _lastBottomHeight = 0;

  _DraggableState(ChatModel? chatModel) {
    _chatModel = chatModel;
  }

  get position => widget.position.pos;

  void onPanUpdate(DragUpdateDetails d) {
    final offset = d.delta;
    final size = MediaQuery.of(context).size;
    double x = 0;
    double y = 0;

    if (position.dx + offset.dx + widget.width > size.width) {
      x = size.width - widget.width;
    } else if (position.dx + offset.dx < 0) {
      x = 0;
    } else {
      x = position.dx + offset.dx;
    }

    if (position.dy + offset.dy + widget.height > size.height) {
      y = size.height - widget.height;
    } else if (position.dy + offset.dy < 0) {
      y = 0;
    } else {
      y = position.dy + offset.dy;
    }
    setState(() {
      widget.position.update(Offset(x, y));
    });
    _chatModel?.setChatWindowPosition(position);
  }

  checkScreenSize() {}

  checkKeyboard() {
    final bottomHeight = MediaQuery.of(context).viewInsets.bottom;
    final currentVisible = bottomHeight != 0;

    // save
    if (!_keyboardVisible && currentVisible) {
      _saveHeight = position.dy;
    }

    // reset
    if (_lastBottomHeight > 0 && bottomHeight == 0) {
      setState(() {
        widget.position.update(Offset(position.dx, _saveHeight));
      });
    }

    // onKeyboardVisible
    if (_keyboardVisible && currentVisible) {
      final sumHeight = bottomHeight + widget.height;
      final contextHeight = MediaQuery.of(context).size.height;
      if (sumHeight + position.dy > contextHeight) {
        final y = contextHeight - sumHeight;
        setState(() {
          widget.position.update(Offset(position.dx, y));
        });
      }
    }

    _keyboardVisible = currentVisible;
    _lastBottomHeight = bottomHeight;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.checkKeyboard) {
      checkKeyboard();
    }
    if (widget.checkScreenSize) {
      checkScreenSize();
    }
    return Stack(children: [
      Positioned(
          top: position.dy,
          left: position.dx,
          width: widget.width,
          height: widget.height,
          child: widget.builder(context, onPanUpdate))
    ]);
  }
}

class IOSDraggable extends StatefulWidget {
  const IOSDraggable(
      {Key? key,
      this.chatModel,
      required this.position,
      required this.width,
      required this.height,
      required this.builder})
      : super(key: key);

  final DraggableKeyPosition position;
  final ChatModel? chatModel;
  final double width;
  final double height;
  final Widget Function(BuildContext) builder;

  @override
  IOSDraggableState createState() =>
      IOSDraggableState(chatModel, width, height);
}

class IOSDraggableState extends State<IOSDraggable> {
  late ChatModel? _chatModel;
  late double _width;
  late double _height;
  bool _keyboardVisible = false;
  double _saveHeight = 0;
  double _lastBottomHeight = 0;

  IOSDraggableState(ChatModel? chatModel, double w, double h) {
    _chatModel = chatModel;
    _width = w;
    _height = h;
  }

  DraggableKeyPosition get position => widget.position;

  checkKeyboard() {
    final bottomHeight = MediaQuery.of(context).viewInsets.bottom;
    final currentVisible = bottomHeight != 0;

    // save
    if (!_keyboardVisible && currentVisible) {
      _saveHeight = position.pos.dy;
    }

    // reset
    if (_lastBottomHeight > 0 && bottomHeight == 0) {
      setState(() {
        position.update(Offset(position.pos.dx, _saveHeight));
      });
    }

    // onKeyboardVisible
    if (_keyboardVisible && currentVisible) {
      final sumHeight = bottomHeight + _height;
      final contextHeight = MediaQuery.of(context).size.height;
      if (sumHeight + position.pos.dy > contextHeight) {
        final y = contextHeight - sumHeight;
        setState(() {
          position.update(Offset(position.pos.dx, y));
        });
      }
    }

    _keyboardVisible = currentVisible;
    _lastBottomHeight = bottomHeight;
  }

  @override
  Widget build(BuildContext context) {
    checkKeyboard();
    return Stack(
      children: [
        Positioned(
          left: position.pos.dx,
          top: position.pos.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                position.update(position.pos + details.delta);
              });
              _chatModel?.setChatWindowPosition(position.pos);
            },
            child: Material(
              child: Container(
                width: _width,
                height: _height,
                decoration:
                    BoxDecoration(border: Border.all(color: MyTheme.border)),
                child: widget.builder(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QualityMonitor extends StatelessWidget {
  final QualityMonitorModel qualityMonitorModel;
  QualityMonitor(this.qualityMonitorModel);

  Widget _row(String info, String? value, {Color? rightColor}) {
    return Row(
      children: [
        Expanded(
            flex: 8,
            child: AutoSizeText(info,
                style: TextStyle(color: Color.fromARGB(255, 210, 210, 210)),
                textAlign: TextAlign.right,
                maxLines: 1)),
        Spacer(flex: 1),
        Expanded(
            flex: 8,
            child: AutoSizeText(value ?? '',
                style: TextStyle(color: rightColor ?? Colors.white),
                maxLines: 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
      value: qualityMonitorModel,
      child: Consumer<QualityMonitorModel>(
          builder: (context, qualityMonitorModel, child) => qualityMonitorModel
                  .show
              ? Container(
                  constraints: BoxConstraints(maxWidth: 200),
                  padding: const EdgeInsets.all(8),
                  color: MyTheme.canvasColor.withAlpha(150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row("Speed", qualityMonitorModel.data.speed ?? '-'),
                      _row("FPS", qualityMonitorModel.data.fps ?? '-'),
                      // let delay be 0 if fps is 0
                      _row(
                          "Delay",
                          "${qualityMonitorModel.data.delay == null ? '-' : (qualityMonitorModel.data.fps ?? "").replaceAll(' ', '').replaceAll('0', '').isEmpty ? 0 : qualityMonitorModel.data.delay}ms",
                          rightColor: Colors.green),
                      _row("Target Bitrate",
                          "${qualityMonitorModel.data.targetBitrate ?? '-'}kb"),
                      _row(
                          "Codec", qualityMonitorModel.data.codecFormat ?? '-'),
                      _row("Chroma", qualityMonitorModel.data.chroma ?? '-'),
                    ],
                  ),
                )
              : const SizedBox.shrink()));
}

class BlockableOverlayState extends OverlayKeyState {
  final _middleBlocked = false.obs;

  VoidCallback? onMiddleBlockedClick; // to-do use listener

  RxBool get middleBlocked => _middleBlocked;

  void addMiddleBlockedListener(void Function(bool) cb) {
    _middleBlocked.listen(cb);
  }

  void setMiddleBlocked(bool blocked) {
    if (blocked != _middleBlocked.value) {
      _middleBlocked.value = blocked;
    }
  }

  void applyFfi(FFI ffi) {
    ffi.dialogManager.setOverlayState(this);
    ffi.chatModel.setOverlayState(this);
    // make remote page penetrable automatically, effective for chat over remote
    onMiddleBlockedClick = () {
      setMiddleBlocked(false);
    };
  }
}

class BlockableOverlay extends StatelessWidget {
  final Widget underlying;
  final List<OverlayEntry>? upperLayer;

  final BlockableOverlayState state;

  BlockableOverlay(
      {required this.underlying, required this.state, this.upperLayer});

  @override
  Widget build(BuildContext context) {
    final initialEntries = [
      OverlayEntry(builder: (_) => underlying),

      /// middle layer
      OverlayEntry(
          builder: (context) => Obx(() => Listener(
              onPointerDown: (_) {
                state.onMiddleBlockedClick?.call();
              },
              child: Container(
                  color:
                      state.middleBlocked.value ? Colors.transparent : null)))),
    ];

    if (upperLayer != null) {
      initialEntries.addAll(upperLayer!);
    }

    /// set key
    return Overlay(key: state.key, initialEntries: initialEntries);
  }
}
