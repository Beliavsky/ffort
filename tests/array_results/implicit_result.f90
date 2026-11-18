program p
implicit none

print *,seqname(3)
contains
pure function seqname(n)
integer,intent(in)::n
integer::seqname(n)
seqname=n
end function
end program
