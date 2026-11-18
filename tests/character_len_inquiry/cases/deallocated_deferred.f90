program p
implicit none
character(:),allocatable::s
s='abc'
deallocate(s)
print *,s%len
end program
