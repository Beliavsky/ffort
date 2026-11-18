program main
implicit none
character(2)::x(3)
character(8)::s(1,2,1)
x=['aa','bb','cc']
s='KEEP'
write(s(1,2,1),'(a2,":",a2)')x([3,1])
print '(a)',s(1,1,1),s(1,2,1)
end program
