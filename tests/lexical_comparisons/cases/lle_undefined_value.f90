program p
implicit none
character(2)::a
print *,"must not leak",lle(a,"x")
end program
