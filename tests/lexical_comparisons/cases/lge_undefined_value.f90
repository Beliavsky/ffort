program p
implicit none
character(2)::a
print *,"must not leak",lge(a,"x")
end program
