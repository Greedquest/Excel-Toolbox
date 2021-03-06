VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SourceDataWrapper"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'@Folder("SynchronisedList")
'''
'Object to hold source data, and filter it into the grid
' - Raises events when grid might need to do something
' - Holds an always up to date copy of all data seen
'''


Private WithEvents sourceBuffer As ListBuffer     'input buffer to chunkify data
Attribute sourceBuffer.VB_VarHelpID = -1
Public Event DataAdded()
Public Event DataRemoved(ByRef RemovedItems)
Public Event NeedsSortingAndFiltering(ByRef PartialFilterSet) 'trigger filter to output

Private Type TSource
    data As FilterList                           'Complete source data for grid
    output As FilterList                         'Temporary data to be passed to the grid
    Buffer As ListBuffer
End Type

Private this As TSource

Private Sub Class_Initialize()
    Set this.data = New FilterList               'data store
    Set sourceBuffer = New ListBuffer             'events version of buffer
    Set this.Buffer = sourceBuffer               'readable version of buffer
End Sub

'''
'Buffer Interface
'Push items through buffer for better UX
'''

Public Sub AddItems(IterableToAdd As Variant)
    this.Buffer.AddItems IterableToAdd
End Sub

Public Sub AmmendItems(IterableToAmmend As Variant)
    this.Buffer.AmmendItems IterableToAmmend
End Sub

Public Sub RemoveItems(IterableToRemove As Variant)
    this.Buffer.RemoveItems IterableToRemove
End Sub

'''
'Source Wrapper methods
'''

Private Sub sourceBuffer_ItemsAmmended()
    'Need to remove ammended items from grid, then add our own set
    Dim markedItems
    markedItems = sourceBuffer.AmmendedItems
    
    RaiseEvent DataRemoved(markedItems)          'triggers grid to remove items, raises needs aligning event at index of 1st marked item
    RaiseEvent NeedsSortingAndFiltering(markedItems) 'Filters newly ammended source to grid
End Sub

Private Sub sourceBuffer_ItemsRemoved()
    Dim markedItems                              'remove items from source and mark to remove from grid
    markedItems = sourceBuffer.RemovalItems
    Dim i As Long
    For i = 1 To UBound(markedItems)
        this.data.Remove markedItems(i)
        this.output.Remove markedItems(i)        'remove from output too if present
    Next i
    RaiseEvent DataRemoved(markedItems)          'triggers grid to remove items
End Sub

Private Sub sourceBuffer_ItemsAdded()
    'When buffer shows new items
    ' - add them the data store (if they are the right type)
    ' - send to output queue which raises item added event to grid manager
    Dim newArray
    newArray = this.Buffer.AddedItems
    Dim i As Long
    For i = 1 To UBound(newArray)
        If this.data.Contains(newArray(i)) Then
            'check for duplicates as these will confuse the re-filtering system
            'Could check whether adding new stuff or just refiltering
            'But then stuff caught in a truly async buffer will be overlooked
            'So a buffer.Flush method and an grid.add(vals,addingNewStuff As boolean)
            Err.Description = "You can't add the same item to the list twice!"
            Err.Raise 5
        Else
            this.data.Add newArray(i)
        End If
    Next i
    RaiseEvent NeedsSortingAndFiltering(newArray) 'Tell grid manager to filter source to output (only added items though)
End Sub

Public Sub SortAndFilterToOutput(FilterObject As Variant, FilterMode As lstFilterMode, FilterComparer As IComparer, SortComparer As IComparer, SortMode As lstSortMode, Optional PartialSet As Variant)
    'Pass filtered and sorted copy of data to output queue, which will be buffered into Grid
    'TODO Sort ascending, descending or maintain order - maintain order makes it hard to find first index

    If this.output Is Nothing Then
        Set this.output = this.data.Clone
    ElseIf isIterable(PartialSet) Then
        Dim outboundItem As Variant
        For Each outboundItem In PartialSet
            this.output.Add outboundItem
        Next outboundItem
    Else                                         'no partial set, i.e. grid was cleared
        Set this.output = this.data.Clone
    End If

    '    If IsMissing(PartialSet) Then
    '        Set this.Output = this.Data.Clone
    '    ElseIf this.Output Is Nothing Then           'OR patrialset Is Nothing
    '        Set this.Output = this.Data.Clone
    '    ElseIf PartialSet Is Nothing Then
    '        Set this.Output = this.Data.Clone
    '    Else                                         'only want to add new items
    '        Dim outboundItem
    '        For Each outboundItem In PartialSet
    '            this.Output.Add outboundItem
    '        Next outboundItem
    '    End If

    '    Dim tempOutput As FilterList
    '    Set tempOutput = this.Output
    this.output.Filter FilterObject, FilterMode, FilterComparer 'Filter list using dummy object based on current settings
    If this.output.Count > 0 Then
        this.output.Sort SortComparer, SortMode
        RaiseEvent DataAdded                     'Let gridManager know there's new data ready
    End If
End Sub

Public Function AddedData() As FilterList
    Set AddedData = this.output.Clone            'or it gets cleared immediately
    this.output.Clear
End Function

'User Interface

Public Property Get RawData() As FilterList
    Set RawData = this.data.Clone
End Property

Public Sub ReSortAndFilter()
    RaiseEvent NeedsSortingAndFiltering(Nothing)
End Sub

