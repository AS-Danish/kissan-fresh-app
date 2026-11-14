import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// Controllers expose independently listenable fields so a stock update only
// rebuilds the widgets that read that part of the model.
class Observable<T> extends ChangeNotifier implements ValueListenable<T> {
  Observable(this._value);
  T _value;

  @override
  T get value {
    FieldBuilder.observe(this);
    return _value;
  }

  set value(T value) {
    if (_value == value) return;
    _value = value;
    notifyListeners();
  }

  void refresh() => notifyListeners();
}

class ObservableList<T> extends ListBase<T>
    implements ValueListenable<List<T>> {
  ObservableList(List<T> initial) : _data = Observable(List.of(initial));
  final Observable<List<T>> _data;
  @override
  List<T> get value => _data.value;
  set value(List<T> items) => _data.value = List.of(items);
  @override
  int get length => value.length;
  @override
  set length(int length) => value = List.of(value)..length = length;
  @override
  T operator [](int index) => value[index];
  @override
  void operator []=(int index, T item) =>
      value = List.of(value)..[index] = item;
  @override
  void add(T element) => value = [...value, element];
  @override
  void addAll(Iterable<T> iterable) => value = [...value, ...iterable];
  @override
  void insert(int index, T element) =>
      value = List.of(value)..insert(index, element);
  @override
  T removeAt(int index) {
    final items = List<T>.of(value);
    final item = items.removeAt(index);
    value = items;
    return item;
  }

  @override
  bool remove(Object? element) {
    final items = List<T>.of(value);
    if (!items.remove(element)) return false;
    value = items;
    return true;
  }

  @override
  void removeWhere(bool Function(T) test) =>
      value = List.of(value)..removeWhere(test);
  @override
  void sort([int Function(T, T)? compare]) =>
      value = List.of(value)..sort(compare);
  @override
  void clear() => value = [];
  void assignAll(Iterable<T> items) => value = items.toList();
  void refresh() => _data.refresh();
  @override
  void addListener(VoidCallback listener) => _data.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => _data.removeListener(listener);
}

class ObservableMap<K, V> extends MapBase<K, V>
    implements ValueListenable<Map<K, V>> {
  ObservableMap(Map<K, V> initial) : _data = Observable(Map.of(initial));
  final Observable<Map<K, V>> _data;
  @override
  Map<K, V> get value => _data.value;
  @override
  Iterable<K> get keys => value.keys;
  @override
  V? operator [](Object? key) => value[key];
  @override
  void operator []=(K key, V item) => _data.value = Map.of(value)..[key] = item;
  @override
  void clear() => _data.value = {};
  @override
  V? remove(Object? key) {
    final items = Map<K, V>.of(value);
    final item = items.remove(key);
    _data.value = items;
    return item;
  }

  void assignAll(Map<K, V> items) => _data.value = Map.of(items);
  @override
  void addListener(VoidCallback listener) => _data.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => _data.removeListener(listener);
}

class FieldBuilder extends StatefulWidget {
  const FieldBuilder(this.builder, {super.key});
  final Widget Function() builder;
  static Set<Listenable>? _dependencies;
  static void observe(Listenable field) => _dependencies?.add(field);
  @override
  State<FieldBuilder> createState() => _FieldBuilderState();
}

class _FieldBuilderState extends State<FieldBuilder> {
  Set<Listenable> _fields = {};
  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final parent = FieldBuilder._dependencies;
    final fields = <Listenable>{};
    FieldBuilder._dependencies = fields;
    try {
      return widget.builder();
    } finally {
      FieldBuilder._dependencies = parent;
      for (final field in _fields.difference(fields)) {
        field.removeListener(_update);
      }
      for (final field in fields.difference(_fields)) {
        field.addListener(_update);
      }
      _fields = fields;
    }
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.removeListener(_update);
    }
    super.dispose();
  }
}

class FieldSubscription {
  FieldSubscription(this.dispose);
  final VoidCallback dispose;
}

FieldSubscription subscribeToField<T>(
  ValueListenable<T> field,
  void Function(T) callback, {
  Duration? delay,
}) {
  Timer? timer;
  void update() {
    if (delay == null) {
      callback(field.value);
    } else {
      timer?.cancel();
      timer = Timer(delay, () => callback(field.value));
    }
  }

  field.addListener(update);
  return FieldSubscription(() {
    timer?.cancel();
    field.removeListener(update);
  });
}

class FeatureController {
  final List<FieldSubscription> _subscriptions = [];
  bool isClosed = false;
  final changes = Observable(0);
  void onInit() {}
  void onClose() {
    isClosed = true;
    for (final subscription in _subscriptions) {
      subscription.dispose();
    }
    changes.dispose();
  }

  void notifyChanged() => changes.value++;

  FieldSubscription observeField<T>(
    ValueListenable<T> field,
    void Function(T) callback, {
    Duration? delay,
  }) {
    final subscription = subscribeToField(field, callback, delay: delay);
    _subscriptions.add(subscription);
    return subscription;
  }
}
