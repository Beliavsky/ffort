program main
implicit none
print '(a)',labels()
contains
pure function labels() result(a)
character(2)::a(1)
write(a(1),'(i2.2)')7
end function
end program
