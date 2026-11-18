implicit none
integer::i
character(*),parameter::a=char(65,kind=kind(achar(i)))
print *,kind(achar(i))
print '(a)',a
end
