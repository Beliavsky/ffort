program p
implicit none
character(24)::fmt
integer::i
fmt='(*(a,:,","))'
print fmt,(mark(i),i=1,4)
contains
pure function mark(n) result(s)
integer,intent(in)::n
character(2)::s
write(s,'(i2.2)')n
end function
end program
