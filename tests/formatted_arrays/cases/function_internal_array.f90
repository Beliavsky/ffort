program main
implicit none
print '(a)',text()
contains
function text() result(s)
character(9)::s
integer::a(3)
a=[1,2,3]
write(s,'(3i3)') a
end function
end program
