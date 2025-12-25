using Knjigoteka.Model.Requests;
using Knjigoteka.Model.Responses;
using Knjigoteka.Model.SearchObjects;
using Knjigoteka.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly IUserService _auth;

    public UserController(IUserService auth) => _auth = auth;

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterRequest dto)
    {
        await _auth.RegisterAsync(dto);
        return Ok(new { message = "Registration successful." });
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest dto)
    {
        var result = await _auth.LoginAsync(dto);
        return Ok(result);
    }
    [HttpGet("me")]
    public async Task<ActionResult<UserResponse>> GetCurrentUser()
    {
        return await _auth.GetCurrentUserAsync();
    }
    [Authorize(Roles = "Admin, Employee")]
    [HttpGet]
    public async Task<ActionResult<List<UserResponse>>> GetAll(UserSearchObject? search)
    {
        var users = await _auth.GetAllAsync(search);
        return Ok(new { items = users });
    }
    [HttpPost("change-password")]
    public async Task<ActionResult<ChangePasswordResponse>> ChangePassword([FromBody] ChangePasswordRequest dto)
    {
        try
        {
            return Ok(await _auth.ChangePasswordAsync(dto));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Greška na serveru: " + ex.Message });
        }
    }
    [HttpPost("edit-profile")]
    public async Task<ActionResult<EditProfileResponse>> EditProfile([FromBody] EditProfileRequest dto)
    {
        return Ok(await _auth.EditProfileAsync(dto));
    }


}
