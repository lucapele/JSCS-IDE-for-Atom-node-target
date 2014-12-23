###
  lib/breakpoint.coffee
###

module.exports = 
class Breakpoint
  
  constructor: (@breakpointMgr, args) ->
    {@file, @line, @column, @enabled, @condition, @ignoreCount} = args
    @id = @file + '|' + @line + '|' + Date.now()
    if not @enabled?
      @enabled = yes
      @condition = 'true'
      @ignoreCount = 0
  
  changeBreakpoint: -> if not @destroyed then @breakpointMgr.changeBreakpoint @
  
  setEnabled:     (@enabled)     -> @changeBreakpoint()
  setCondition:   (@condition)   -> @changeBreakpoint()
  setIgnoreCount: (@ignoreCount) -> @changeBreakpoint()
      
  getData: -> {@id, @file, @line, @column, @enabled, @condition, @ignoreCount}
  
  destroy: ->
    @destroyed = yes
