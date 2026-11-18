program main
implicit none
character(4)::a(3)
character(6)::fmt
integer::i
a='old!'
i=2
fmt='(i3.3)'
write(unit=a(i),fmt=fmt)17
print '(a)',a
end program
