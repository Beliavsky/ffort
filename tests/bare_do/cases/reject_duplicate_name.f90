program p
implicit none
integer::i
outer: do
exit
end do outer
outer: do
exit
end do outer
end program
