program p

implicit none
character(8)::s(2)
integer::i
write(s(2),'(4z2.2)')(maskr(i),i=0,3)
print '(a)',s(2)
print '(i0)',i
end program
