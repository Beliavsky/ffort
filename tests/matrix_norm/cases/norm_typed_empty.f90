program p
if(norm2([real::])/=0.) error stop 1
if(norm2([real(kind=8)::],1)/=0d0) error stop 2
end program
