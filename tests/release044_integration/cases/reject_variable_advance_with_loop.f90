program p
implicit none
integer::i
character(24)::fmt
character(2)::adv
fmt='(*(i0))'
adv='no'
write(*,fmt,advance=adv)(i,i=1,2)
end program
