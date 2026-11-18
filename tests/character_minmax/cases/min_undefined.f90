program p
implicit none
character(2)::a
print *,'must not leak',min(a,'z')
end program
