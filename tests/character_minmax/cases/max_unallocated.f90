program p
implicit none
character(:),allocatable::a
print *,'must not leak',max(a,'z')
end program
