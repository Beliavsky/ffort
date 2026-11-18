program main
implicit none
integer::a(3)=[1,2,3]
character(30)::s
write(s,'(3i3)') a
print '(a)',s
write(s,'(5i3)') a
print '(a)',s
write(s,'("x",3i3)') a(1:0)
print '(a)',s

end program
