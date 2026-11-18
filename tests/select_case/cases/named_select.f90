program p
implicit none
outer:select case(1)
case(1) outer
print *,1
end select outer
end program p
