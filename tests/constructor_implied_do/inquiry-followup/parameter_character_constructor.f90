program main
implicit none
integer::i
character(3),parameter::a(2)=[("ab ",i=1,2)]
print '(2("[",a,"]"))',a
end program
