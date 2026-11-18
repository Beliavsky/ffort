module text_math
implicit none
character(*), parameter :: titles(2)=[character(3)::"sin","cos"], punctuation=achar(33)
character(*), parameter :: codes(2)=achar([65,66])
real(8), parameter :: unit=sin(0.0_8)+cos(0.0_8)+tan(0.0_8)
contains
function decorate(words,n) result(answer)
character(*),intent(in)::words(:)
integer,intent(in)::n
character(len(words)+n)::answer(size(words))
answer=words//punctuation
end function
end module
program combined
use text_math
implicit none
character(4)::work(2)
work=decorate(titles,int(unit))
print '(2A4)',work
print '(2A2)',decorate(codes,1)
print '(I1)',int(unit)
print '(I1,I1)',len(achar(65)),len(achar([65,66]))
print '(2A2)',decorate(achar([65,66]),1)
end program
