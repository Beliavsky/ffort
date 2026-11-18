program p
print *,kind(min(f(),"x")),len(min(f(),"x"))
contains
character(2) function f()
integer::i
i=0
f=repeat("a",1/i)
end function
end program
