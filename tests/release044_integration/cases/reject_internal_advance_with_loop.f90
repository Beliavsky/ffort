program p
implicit none
integer::i
character(24)::fmt,s
fmt='(*(i0))'
write(s,fmt,advance='no')(i,i=1,2)
end program
