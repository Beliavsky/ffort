program p
implicit none
character(12)::fmt
character(4)::s
fmt='(i0)'
write(s,fmt)123
print '(a)',s
end program
