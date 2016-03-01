{newLine, funcString} = require('dc-util')

{bind, duplex, react} = flow = require("lazy-flow")

module.exports = flow

atMethod = (method) -> (root, path) ->

  if arguments.length==1
    path = root
    if typeof window != 'undefined' then root = window # browser environment
    else root = global # node.js environment

  # path should be a string or an array
  if typeof path == 'string'
    path = path.split(/\.\s*/)

  if !path.length then return root

  if typeof root != 'object'
    throw new Error 'expect an object as the root of flow.at'

  len = path.length
  if len == 0 then return root

  reactive = react (value) ->
    if arguments.length
      i = 0
      parent = root

      while i < len-1
        item = parent[path[i]]
        if !item?
          item = parent[path[i]] = {}
        else if typeof parent != 'object'
          throw new Error 'expect an object'
        parent = item
        i++

      parent[path[i]] = value

      if reactive.cacheValue != value
        reactive.cacheValue = value
        reactive.invalidate()
        reactive.valid = false

      value

    else
      reactive.valid = true
      i = 0
      item = root
      while i < len
        if !item then return
        item = item[ path[i]]
        i++
      reactive.cacheValue = item

  if method == duplex then reactive.isDuplex = true

  invalidateBindPath(root, path, reactive, method)

invalidateBindPath = (root, path, atFunc, method) ->
  len = path.length
  if !len then return atFunc

  parent = root
  i = 0
  while i<len
    if !parent then return
    attr = path[i]
    bound = method(parent, attr)
    bound.onInvalidate ->
      invalidateBindPath(parent[attr], path.slice(i+1), atFunc)
      atFunc.invalidate()
    i++

  atFunc

flow.at = atMethod(bind)
flow.at2 = atMethod(duplex)

# return a group of flow at
# pathPattern: 'x.y, '[x, y].z', 'x.[y,z]', ...
# for flow.paths(obj, 'x.[y,z]'), return [flow.at(obj, ['x', 'y']), flow.at(obj, ['x', 'z'])]
flow.paths = (obj, pathPattern) ->
  itemList = pathPattern.split(/\s*\.\s*/)
  paths = []
  for item in itemList
    if item[0]=='['
      length = item.length
      if item[item.length-1]!=']'
        throw new Error("wrong format of pathPattern for flow.paths, expect string like 'x.y, '[x, y].z', 'x.[y,z]' ...")
      item = item.slice(1, length-1)
      paths.push(item.split(/\s*\.\s*|\s+/))
    else paths.push([item])
  pathList = paths[0]
  for item in paths.slice(1)
    pathList2 = []
    for head in pathList
      for x in path
        pathList2.push(head.concat([x]))
    pathList = pathList2
  flowPaths = []
  for item in pathList
    flowPaths.push(at(obj, item))
  flowPaths

