program main
implicit none
integer::i
character(3)::x(3)
character(4)::a(3)
x=[" a ","b  ","   "]
a=[character(4)::(x(i),i=1,3)]
print '(3("[",a,"]"))',a
end program
