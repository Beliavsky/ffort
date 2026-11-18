program p
implicit none
character(3),allocatable::s
s='old'
deallocate(s)
print *,s
end program
