program main
implicit none
integer::i
character(0)::a(3)
a=[("",i=1,3)]
print '(3("[",a,"]"))',a
end program
