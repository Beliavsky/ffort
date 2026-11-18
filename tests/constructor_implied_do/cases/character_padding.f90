program main
implicit none
integer::i
character(3)::x(3),a(6)
x=[" a ","b  ","   "]
a=[(x(i),x(4-i),i=1,3)]
print '(6("[",a,"]"))',a
end program
