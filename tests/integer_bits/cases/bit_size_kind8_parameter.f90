program bits_driver
implicit none
integer(8)::a
integer,parameter::n=bit_size(a)
integer,parameter::k=n/8
integer(k)::b
print *,n,kind(b)
end program
