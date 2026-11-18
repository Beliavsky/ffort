program main
implicit none
integer::i
character(6)::a(4)
a=[("i=1,2 ","(x,y) ",i=1,2)]
print '(4("[",a,"]"))',a
end program
