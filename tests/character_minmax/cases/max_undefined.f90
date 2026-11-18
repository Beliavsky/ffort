program p
implicit none
character(2)::a
print *,'must not leak',max(a,'z')
end program
