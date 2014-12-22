###
   lib/code-display.coffee
###

{$}          = require 'atom-space-pen-views'

module.exports =
class CodeDisplay
  
  constructor: (ideVew) ->
    @subs = []
    @breakpointDecorationsById = {}
    @setupEvents()
  
  setCodeExec: (@codeExec) ->

  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
      
  showCurExecLine: (curExecPosition, cb) -> 
    @removeCurExecLine()
    {file, line, column} = curExecPosition
    editor = @findShowEditor file, line, (editor) =>
      @execPosMarker = editor.markBufferPosition [line, 0]
      editor.decorateMarker @execPosMarker, 
                            type: 'line', class: 'node-ide-exec-line'
      cb?()
      
  removeCurExecLine: -> 
    if @execPosMarker
      @execPosMarker.destroy()
      @execPosMarker = null
  
  addBreakpoint: (breakpoint) ->
    file = breakpoint.file
    line = breakpoint.line
    editor = @findShowEditor file, line, (editor) =>
      marker = editor.markBufferPosition [line, 0]
      decoration = editor.decorateMarker marker, 
                    type: 'gutter', class: 'node-ide-breakpoint-enabled'
      @breakpointDecorationsById[breakpoint.id] = decoration
      console.log 'addBreakpoint', @breakpointDecorationsById, breakpoint.id

  showBreakpointEnabled: (breakpointId, enabled) ->
    console.log 'showBreakpointEnabled', @breakpointDecorationsById, breakpointId
    if (decoration = @breakpointDecorationsById[breakpointId])
      decoration.setProperties 
        type:  'gutter'
        class: 'node-ide-breakpoint' +
                (if enabled then '-enabled' else '-disabled')
  
  removeBreakpoint: (breakpointId) -> 
      console.log 'removeBreakpoint', @breakpointDecorationsById, breakpointId
      @breakpointDecorationsById[breakpointId]?.getMarker().destroy()
      delete @breakpointDecorationsById[breakpointId]

  setupEvents: ->
    @subs.push $('atom-pane-container').on 'click', '.line-number', (e) =>
      $tgt = $ e.target
      editor = $tgt.closest('atom-text-editor')[0].getModel()
      line   = $tgt.closest('.line-number').attr 'data-buffer-row'
      @codeExec.toggleBreakpoint editor, +line
  
  destroy: ->
    @removeCurExecLine()
    for id of @breakpointDecorationsById
        @removeBreakpoint id
    for sub in @subs
      sub.off?()
      sub.dispose?()
