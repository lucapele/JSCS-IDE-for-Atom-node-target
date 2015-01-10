###
   lib/code-display.coffee
###

{TextEditor} = require 'atom'
{$} = require 'atom-space-pen-views'
_   = require 'underscore'

module.exports =
class CodeDisplay
  
  constructor: (@breakpointMgr) ->
    {Disposable, CompositeDisposable} = require 'atom'
    disposables = new CompositeDisposable
    @subs = []
    
    atom.workspace.observeTextEditors (editor) =>
      file = @getPath editor
      if file is @curExecPosition?.file then @showCurExecLine()
      @setBreakpointsInEditor editor
      
      shadowRoot  = atom.views.getView(editor).shadowRoot
      $shadowRoot = $ shadowRoot
      lineNumbers = shadowRoot.querySelector '.line-numbers' 
      lineNumberClick = (e) =>
        $tgt = $ e.target
        line = +$tgt.closest('.line-number').attr 'data-buffer-row'
        @breakpointMgr.toggleBreakpoint file, line
        false
      lineNumbers.addEventListener 'click', lineNumberClick
      disposables.add new Disposable ->
        lineNumbers.removeEventListener 'click', lineNumberClick
        
      @subs.push $shadowRoot.find('.gutter .icon-right').on 'click', => @showAll()
      @subs.push $shadowRoot.find('.lines .fold-marker').on 'click', => @showAll()
        
  getPath: (editor) ->
    path = editor.getPath()
    if (pathParts = /^([a-z]:)(.*)$/i.exec path)
      path = pathParts[1].toUpperCase() + pathParts[2]
    path
  
  findShowEditor: (file, line, cb) ->
    atom.workspace.open file, searchAllPanes: yes, initialLine: line-1
      .then (editor) -> cb editor
  
  setCursorToLineColDelayed: (editor, line, column) ->
    if editor is atom.workspace.getActivePaneItem()
      setTimeout ->
        editor.setCursorBufferPosition [line, column]
      , 50
  
  showCurExecLine: (execPosition) ->
    if execPosition then @curExecPosition = execPosition
    @removeCurExecLine yes
    if @curExecPosition
      {file, line, column} = @curExecPosition
      @findShowEditor file, line, (editor) =>
        do setMarker = (editor) ->
          editor.nodeIdeExecMarker = editor.markBufferPosition [line, column]
          editor.decorateMarker editor.nodeIdeExecMarker, 
                type: 'gutter', class: 'node-ide-exec-line'
        @setCursorToLineColDelayed editor, line, column
        for otherEditor in atom.workspace.getTextEditors() 
          if @getPath(otherEditor) is file and otherEditor isnt editor
            setMarker otherEditor
        null
      
  removeCurExecLine: (temp = no) ->
    if not temp then delete @curExecPosition
    for editor in atom.workspace.getTextEditors()
      editor.nodeIdeExecMarker?.destroy()
      delete editor.nodeIdeExecMarker
    null

  getDecorationData: (breakpoint) ->
    enbldActive = breakpoint.enabled and breakpoint.active
    type: 'gutter', class: 'node-ide-breakpoint-' +
      (if enbldActive then 'enabled' else 'disabled')
      
  removeBreakpointsFromEditor: (editor) ->
    if editor.nodeIdeBreakpoints
      for id, decoration of editor.nodeIdeBreakpoints
        decoration.getMarker()?.destroy()
      delete editor.nodeIdeBreakpoints
  
  setBreakpointsInEditor: (editor) ->
    path = @getPath editor
    @removeBreakpointsFromEditor editor
    editor.nodeIdeBreakpoints = {}
    for id, breakpoint of @breakpointMgr.breakpoints
      if breakpoint.file is path and not editor.nodeIdeBreakpoints[id]
        {line, column} = breakpoint
        marker = editor.markBufferPosition [line, column]
        decoration = editor.decorateMarker marker, @getDecorationData breakpoint
        editor.nodeIdeBreakpoints[id] = decoration
    null
    
  setAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      @setBreakpointsInEditor editor
    null
  
  showBreakpoint: (breakpoint) ->
    {file, line, column} = breakpoint
    @findShowEditor file, line, (editor) =>
      editor.unfoldBufferRow line
      @setAllBreakpoints()
      @setCursorToLineColDelayed editor, line, column
      null
      
  changeBreakpoint: (breakpoint) ->
    decorationData = @getDecorationData breakpoint
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeBreakpoints?[breakpoint.id])
        decoration.setProperties decorationData
    null
    
  removeBreakpoint: (breakpoint) -> 
    for editor in atom.workspace.getTextEditors()
      if (decoration = editor.nodeIdeBreakpoints?[breakpoint.id])
        decoration.getMarker()?.destroy()
    null    
    
  removeAllBreakpoints: ->
    for editor in atom.workspace.getTextEditors()
      @removeBreakpointsFromEditor editor
    null
    
  showAll: (execPosition) ->
    setTimeout =>
      @setAllBreakpoints()
      @showCurExecLine execPosition
    , 50
    
  destroy: ->
    @removeCurExecLine()
    @removeAllBreakpoints()
    disposables.dispose()
    for sub in @subs
      sub.off?()
      sub.dispose?()
    null
    