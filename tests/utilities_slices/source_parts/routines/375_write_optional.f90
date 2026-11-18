subroutine write_optional(outu,xfmt)
integer          , intent(in), optional :: outu
character (len=*), intent(in), optional :: xfmt
if (xfmt /= "") write (default(istdout,outu),xfmt)
end subroutine write_optional
!
