import 'package:mesh_note/mindeditor/document/doc_content.dart';

enum ContentOperationType {
  add,
  del,
  move,
  rename,
  modify,
}

class ContentOperation {
  ContentOperationType operation;
  String targetId;
  String? parentId;
  String? previousId;
  String? title;
  String? data;
  bool _valid = true;
  int timestamp;

  ContentOperation({
    required this.operation,
    required this.targetId,
    this.parentId,
    this.previousId,
    this.title,
    this.data,
    required this.timestamp,
  });

  bool isValid() => _valid;
  void setInvalid() {
    _valid = false;
  }
}

class DiffOperations {
  String versionHash;
  List<ContentOperation> operations;
  // VersionContent versionContent;

  DiffOperations({
    // required this.versionContent,
    required this.operations,
    required this.versionHash,
  });

  // factory DiffOperations.fromContentChange(List<ContentNode> nodes) {
  //   List<ContentOperation> operations = [];
  //   String? lastNodeId;
  //   for(var item in nodes) {
  //     final contentId = item.contentId;
  //     ContentOperation? op;
  //     switch(item.operation) {
  //       case _operationAdd:
  //         op = ContentOperation(operation: ContentOperationType.add, targetId: contentId, parentId: null, previousId: lastNodeId, title: item.contentName, data: item.contentHash);
  //         break;
  //       case _operationDel:
  //         op = ContentOperation(operation: ContentOperationType.del, targetId: contentId);
  //         break;
  //       case _operationMove:
  //         op = ContentOperation(operation: ContentOperationType.move, targetId: contentId, parentId: null, previousId: lastNodeId);
  //         break;
  //       case _operationRename:
  //         op = ContentOperation(operation: ContentOperationType.rename, targetId: contentId, title: item.contentName);
  //         break;
  //       case _operationModify:
  //         op = ContentOperation(operation: ContentOperationType.modify, targetId: contentId, data: item.contentHash);
  //         break;
  //     }
  //     if(op != null) {
  //       operations.add(op);
  //     }
  //     if(item.operation != _operationDel) {
  //       lastNodeId = item.contentId;
  //     }
  //   }
  //   return DiffOperations(operations: operations);
  // }
  factory DiffOperations.fromContent(VersionContent versionContent) {
    List<ContentOperation> operations = [];
    String? lastNodeId;
    int timestamp = versionContent.timestamp;
    for(var item in versionContent.table) {
      var op = ContentOperation(
        operation: ContentOperationType.add,
        targetId: item.docId,
        parentId: null,
        previousId: lastNodeId,
        title: item.title,
        data: item.docHash,
        timestamp: timestamp,
      );
      operations.add(op);
      lastNodeId = item.docId;
    }
    return DiffOperations(operations: operations, versionHash: versionContent.getHash());
  }
}

const int _operationNone = 0;
const int _operationAdd = 1;
const int _operationDel = 2;
const int _operationMove = 4;
const int _operationRename = 8;
const int _operationModify = 16;

class ContentNode {
  String contentId;
  String contentName;
  String contentHash;
  String? parentId;
  String? previousId;
  int updatedAt;
  int operation = _operationNone;

  ContentNode({
    required this.contentId,
    required this.contentName,
    required this.contentHash,
    this.parentId,
    this.previousId,
    required this.updatedAt,
  });
}
class DiffManager {
  /// Find diff operations to convert from version2 to version1
  /// 0. If version2 is empty, return operations of version1
  /// 1. Convert contents of version1 and 2 from list to map
  /// 2. Label nodes with operations in version1
  ///   2.1 If any item appears in version1 but not in version2, that's added
  ///   2.2 If any item appears in version2 but not in version1, that's deleted
  ///   2.3 If any item appears both in version1 and version2
  ///     2.3.1 but with different parent or previous node, that's moved
  ///     2.3.2 but with different name, that's renamed
  ///     2.3.3 but with different hash, that's modified
  ///     2.3.4 the operations above may occur at the same time
  ///   2.4 Otherwise, the content does not change
  /// 3. Only leave add/delete/move/rename/modify operations
  DiffOperations findDifferentOperation(VersionContent targetVersion, VersionContent? baseVersion) {
    if(baseVersion == null) {
      return DiffOperations.fromContent(targetVersion);
    }

    var (targetList, targetMap) = _convertToContentNodes(targetVersion);
    var (baseList, baseMap) = _convertToContentNodes(baseVersion);

    List<ContentOperation> operations = [];
    int targetIdx = 0, baseIdx = 0;
    String? lastNodeId;
    int timestamp = targetVersion.timestamp;
    while(targetIdx < targetList.length && baseIdx < baseList.length) {
      var targetItem = targetList[targetIdx];
      var baseItem = baseList[baseIdx];
      final targetId = targetItem.contentId;
      final baseId = baseItem.contentId;
      if(targetId == baseId) { // With same ID, maybe rename or modify
        if(targetItem.contentName != baseItem.contentName) {
          var op = ContentOperation(operation: ContentOperationType.rename, targetId: targetId, title: targetItem.contentName, timestamp: timestamp);
          operations.add(op);
        }
        if(targetItem.contentHash != baseItem.contentHash) {
          var op = ContentOperation(operation: ContentOperationType.modify, targetId: targetId, data: targetItem.contentHash, timestamp: timestamp);
          operations.add(op);
        }
        baseIdx++;
      } else { // ID is different in the same position, maybe move or add or del
        if(!targetMap.containsKey(baseId)) { // Should be deleted
          var op = ContentOperation(operation: ContentOperationType.del, targetId: baseId, timestamp: timestamp);
          operations.add(op);
          baseIdx++;
          continue;
        } else {
          if (baseMap.containsKey(targetId)) { // Should be moved
            baseItem = baseMap[targetId]!;
            baseList.remove(baseItem);
            var op = ContentOperation(operation: ContentOperationType.move, targetId: targetId, parentId: null, previousId: lastNodeId, timestamp: timestamp);
            operations.add(op);
            if (targetItem.contentName != baseItem.contentName) {
              var op = ContentOperation(operation: ContentOperationType.rename, targetId: targetId, title: targetItem.contentName, timestamp: timestamp);
              operations.add(op);
            }
            if (targetItem.contentHash != baseItem.contentHash) {
              var op = ContentOperation(operation: ContentOperationType.modify, targetId: targetId, data: targetItem.contentHash, timestamp: timestamp);
              operations.add(op);
            }
          } else { // Should be added
            var op = ContentOperation(
                operation: ContentOperationType.add,
                targetId: targetId,
                parentId: null,
                previousId: lastNodeId,
                title: targetItem.contentName,
                data: targetItem.contentHash,
                timestamp: timestamp,
            );
            operations.add(op);
          }
        }
      }
      lastNodeId = targetId;
      targetIdx++;
    }
    for(; targetIdx < targetList.length; targetIdx++) {
      var targetItem = targetList[targetIdx];
      var op = ContentOperation(
          operation: ContentOperationType.add,
          targetId: targetItem.contentId,
          parentId: null,
          previousId: lastNodeId,
          title: targetItem.contentName,
          data: targetItem.contentHash,
          timestamp: timestamp,
      );
      operations.add(op);
    }
    for(; baseIdx < baseList.length; baseIdx++) {
      var baseItem = baseList[baseIdx];
      var op = ContentOperation(operation: ContentOperationType.del, targetId: baseItem.contentId, timestamp: timestamp);
      operations.add(op);
    }
    //
    // for(var item in baseList) {
    //   var contentId = item.contentId;
    //   var contentName = item.contentName;
    //   var contentHash = item.contentHash;
    //   var nodeInVersion1 = targetMap[contentId];
    //   if(nodeInVersion1 == null) { // Not found in version1, means it is deleted
    //     var newNode = ContentNode(contentId: contentId, contentName: contentName, contentHash: contentHash, updatedAt: item.updatedAt)
    //       ..operation = _operationDel;
    //     targetMap[contentId] = newNode;
    //     continue;
    //   }
    //   if(nodeInVersion1.parentId != item.parentId || nodeInVersion1.previousId != item.previousId) { // With different parent or previous node, means moved
    //     nodeInVersion1.operation |= _operationMove;
    //   }
    //   if(nodeInVersion1.contentName != item.contentName) { // With different title, means renamed
    //     nodeInVersion1.operation |= _operationRename;
    //   }
    //   if(nodeInVersion1.contentHash != item.contentHash) { // With different hash, means modified
    //     nodeInVersion1.operation |= _operationModify;
    //   }
    // }
    // for(var item in targetList) {
    //   var contentId = item.contentId;
    //   if(!baseMap.containsKey(contentId)) { // If not contained in base version, it must be added
    //     item.operation = _operationAdd;
    //   }
    // }
    // return DiffOperations.fromContentChange(targetList);
    return DiffOperations(operations: operations, versionHash: targetVersion.getHash());
  }

  (List<ContentNode>, Map<String, ContentNode>) _convertToContentNodes(VersionContent contentVersion) {
    var list = <ContentNode>[];
    var map = <String, ContentNode>{};
    ContentNode? lastNode;
    for(var item in contentVersion.table) {
      var docId = item.docId;
      var docHash = item.docHash;
      var docTitle = item.title;
      var timestamp = item.updatedAt;
      var node = ContentNode(contentId: docId, contentName: docTitle, contentHash: docHash, previousId: lastNode?.contentId, updatedAt: timestamp);
      list.add(node);
      map[docId] = node;
      lastNode = node;
    }
    return (list, map);
  }
}