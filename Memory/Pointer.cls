VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Pointer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'@Folder("VBAProject")

Option Explicit
'@PredeclaredId

Private Type pointerData
    address As LongPtr
    baseType As VbVarType
    depth As Long
End Type

Public Enum customVBVarTypes
    #If Win64 Then
    vbLongPtr = vbLongLong
    #Else
    vbLongLong = 20
    vbLongPtr = vbLong
    #End If
End Enum

Private this As pointerData

Public Function Create(ByVal address As LongPtr, ByVal dataType As VbVarType, Optional ByVal referenceDepth As Long = 1) As Pointer
    With New Pointer
        Set Create = .Self
        .Init address, dataType, referenceDepth
    End With
End Function

Friend Property Get Self() As Pointer
    Set Self = Me
End Property

Friend Sub Init(ByVal address As LongPtr, ByVal dataType As VbVarType, ByVal referenceDepth As Long)
    this.address = address
    this.depth = referenceDepth
    this.baseType = dataType
End Sub

Public Property Get DeRef() As Pointer
    If this.depth = 1 Then
        'this is a pointer to a variable, not another pointer - so don't dereference or it's riskkkkkyy
        Err.Raise 5, Description:="You can't dereference a pointer to a non-pointer type, either set the base type to vbLongPtr, set the depth greater or use Value to read the value which this points to"
    Else
        Set DeRef = Pointer.Create(DeReference(this.address), this.baseType, this.depth - 1)
    End If
End Property

Public Property Get Value() As Variant
'    Dim result As Variant
'    result = oldValueAt(this.address, lengthFromType(valueType))
'    VariantChangeTypeEx Value, result, LOCALE_INVARIANT, 0, valueType
End Property

Public Property Let Value(ByVal newValue As Variant)
    oldValueAt(this.address, lengthFromType(valueType)) = newValue
End Property

Public Property Set Value(ByVal reference As IUnknown) 'REVIEW: is this weird?
    oldValueAt(this.address, lengthFromType(valueType)) = ObjPtr(reference)
End Property

'@Description("The VarType of this pointer when dereferenced; if this is &a then datatype will be vartype(a), if &&a then datatype will be a pointer)
Private Property Get valueType() As VbVarType
    If this.depth = 1 Then                       'just a pointer to a value, so that value is this class' base type
        valueType = this.baseType
    Else
        valueType = vbLongPtr
    End If
End Property


'Private Function CType(ByVal expression As Variant, ByVal outputType As VbVarType) As Variant
'    Select Case outputType
'        #If Win64 Then
'        Case vbLongLong
'            CType = CLngLng(expression)
'        #End If
'        Case vbBoolean
'            CType = CBool(expression)
'        Case vbByte
'            CType = CByte(expression)
'        Case vbCurrency
'            CType = CCur(expression)
'        Case vbDate
'            CType = CDate(expression)
'        Case vbDecimal
'            CType = CDec(expression)
'        Case vbDouble
'            CType = CDbl(expression)
'        Case vbInteger
'            CType = CInt(expression)
'        Case vbLong
'            CType = CLng(expression)
'        Case vbLongPtr
'            CType = CLngPtr(expression)
'        Case vbSingle
'            CType = CSng(expression)
'        Case vbString
'            CType = CStr(expression)
'        Case vbVariant
'            CType = CVar(expression)
'        Case Else
'            CType = expression
'    End Select
'End Function

Friend Sub DebugPrint()
    Debug.Print printf("Pointer @{3}{4}baseType: {0}{4}depth: {1}{4}value: {2}", this.baseType, this.depth, Value, this.address, vbCrLf & vbTab)
End Sub
