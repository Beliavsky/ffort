program p

implicit none
character(8)::s(3)
character(20)::fmt
fmt='(z2.2,1x,i0)'
write(s(2),fmt=fmt)iand(maskl(4),255),shiftr(maskr(4),1)
print '(a)','['//s(2)//']'
print '(i0)',len(s(1))
end program
